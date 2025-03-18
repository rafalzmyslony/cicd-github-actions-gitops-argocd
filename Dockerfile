# Use an official Python runtime as a base image
FROM python:3.9

# Set the working directory in the container
WORKDIR /app

# Copy requirements.txt and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application files
COPY src/app.py .

# Expose the port Flask runs on
EXPOSE 5000

# Run the Flask app
CMD ["python", "app.py"]

