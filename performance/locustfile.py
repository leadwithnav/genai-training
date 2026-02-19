from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    wait_time = between(1, 5)

    @task
    def index(self):
        self.client.get("/")

    @task(3)
    def view_products(self):
        self.client.get("/api/products")

    @task(1)
    def view_cart(self):
        self.client.get("/api/cart/locust-test-session")
