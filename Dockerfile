FROM python:3.9
LABEL authors="amir"

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
# python -m pip install "Django>=4.1,<4.2"
# python -m pip install pipreqs
# pipreqs . --force


# pip install django python-dotenv Pillow plotly requests pytz bitcoin eth-account django-creditcards





COPY CryptoCurrencyExchange/ .
COPY .env ./Exchange/


WORKDIR ./Exchange
RUN python manage.py migrate
EXPOSE 8000
#CMD ["python", "./manage.py", "runserver"]
CMD ["sleep", "infinity"]
