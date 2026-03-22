from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Welcome to the backend of my fullstack app!"}

# Additional API routes can be defined here.