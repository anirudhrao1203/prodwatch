from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI(title="Inventory Service")
Instrumentator().instrument(app).expose(app)

# In-memory databse- Just python dist for now

inventory = {
	1: {"name": "Wireless Mouse", "quantity": 50},
	2: {"name": "Mechanical Keyboard", "quantity": 30},
	3: {"name": "USB-C Cable", "quantity": 100},
}

class StockUpdate(BaseModel):
	quantity: int

@app.get("/")
def root():
	return {"service": "inventory-service", "status": "running"}

@app.get("/health")
def health():
	return {"status": "healthy"}

@app.get("/stock/{item_id}")
def get_stock(item_id: int):
	if item_id not in inventory:
		raise HTTPException(status_code=404, detail="Item not found")
	return {"item_id": item_id, **inventory[item_id]}
    
@app.post("/stock/{item_id}/reserve")
def reserve_stock(item_id: int, update: StockUpdate):
    if item_id not in inventory:
        raise HTTPException(status_code=404, detail="Item not found")
    if inventory[item_id]["quantity"] < update.quantity:
        raise HTTPException(status_code=400, detail="Insufficient stock")
    inventory[item_id]["quantity"] -= update.quantity
    return {"item_id": item_id, "reserve": update.quantity, "remaining": inventory[item_id]["quantity"]}

