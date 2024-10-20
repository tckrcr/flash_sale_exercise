# app.py

from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({"message": "Hello, World!"})

@app.route('/orders')
def orders():
    return jsonify({"orders": ["order1", "order2", "order3"]})

@app.route('/products')
def products():
    return jsonify({"products": ["product1", "product2", "product3"]})

@app.route('/item/<int:item_id>')
def item(item_id):
    return jsonify({"item_id": item_id, "name": f"Item {item_id}", "price": item_id * 10})

@app.route('/userauth')
def userauth():
    return jsonify({"message": "User authentication endpoint", "status": "success"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
