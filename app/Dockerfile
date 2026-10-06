FROM python:3.12-slim
WORKDIR /app
RUN pip install flask==3.0.3 psycopg2-binary==2.9.9 redis==5.0.4 gunicorn==22.0.0
COPY app.py .
EXPOSE 5000
CMD ["gunicorn","--bind","0.0.0.0:5000","--workers","2","app:app"]
