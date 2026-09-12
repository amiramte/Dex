FROM python:3.9.19
FROM python:3.9
LABEL authors="amir"

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY CryptoCurrencyExchange/* .

#COPY .env ./Exchange/

RUN groupadd -r dex && useradd -r -g dex dex \
    && chown -R dex:dex /app

USER dex


WORKDIR /app/Exchange
#RUN python manage.py migrate
EXPOSE 8000
#CMD ["python", "./manage.py", "runserver"]
#CMD ["sleep", "infinity"]

CMD ["gunicorn", "--chdir", "/app/Exchange", "Exchange.wsgi:application", "--bind", "0.0.0.0:8000"]
