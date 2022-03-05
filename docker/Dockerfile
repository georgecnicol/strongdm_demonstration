# syntax=docker/dockerfile:1
# base image to use from docker
FROM python:3.8-slim-buster

# default location on image
WORKDIR /app

# copy reqs from same dir as dockerfile to /app/reqs on image
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

# add our source code into the image.
COPY . .

CMD ["python3", "-m", "flask", "run", "--host=0.0.0.0"]
#CMD ["python3", "app.py"]