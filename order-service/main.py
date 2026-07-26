import httpx
import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="Order Service")

INVENTORY_SERVICE_URL = os.environ.get("INVENTORY_SERVICE_URL", "http://inventory-service:8000")

orders = {}
next_order_id = 1

class OrderRequest(BaseModel):
	item_id: int
	quantity: int

@app.get("/")
def root():
	return {"service": "order-service", "status": "running"}

@app.get("/health")
def health():
	return {"status": "healthy"}

@app.post("/orders")
def create_order(order: OrderRequest):
	global next_order_id
	response = httpx.post(
		f"{INVENTORY_SERVICE_URL}/stock/{order.item_id}/reserve",
		json={"quantity": order.quantity},
	)

	if  response.status_code == 404:
		raise HTTPException(status_code=404, detail="Item not found in inventory")
	if response.status_code == 400:
		raise HTTPException(status_code=400, detail="Insufficient stock")

	order_id = next_order_id
	next_order_id += 1
	orders[order_id] = {"item_id": order.item_id, "quantity": order.quantity, "status": "confirmed"}

	return {"order_id": order_id, **orders[order_id]}

@app.get("/orders/{order_id}")
def get_order(order_id: int):
	if order_id not in orders:
		raise HTTPException(status_code=404, detail="Order not found")
	return orders[order_id]
