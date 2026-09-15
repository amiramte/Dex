FROM python:3.9.19
FROM python:3.9
LABEL authors="amir"
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY CryptoCurrencyExchange/* .

RUN groupadd -r dex && useradd -r -g dex dex \
    && chown -R dex:dex /app
USER dex

EXPOSE 8000
#CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
#CMD ["sleep", "infinity"]
#CMD ["gunicorn", "--chdir", "/app/Exchange", "wsgi:application", "--bind", "0.0.0.0:8000"]
CMD ["sh", "-c", "gunicorn --chdir /app/Exchange wsgi:application --bind $EXTERNAL_IP_BIND:$EXTERNAL_PORT"]