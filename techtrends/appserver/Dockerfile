FROM python:3.8

COPY . /src

WORKDIR /src

# Dependencies required for psycopg2 (used for Postgres client)
RUN apt update -y && apt install -y build-essential libpq-dev

# Dependencies are installed during build time in the container itself so we don't have OS mismatch
RUN pip install -r requirements.txt

EXPOSE 3111 

CMD [ "python", "app.py" ]