# Dex
Dejango/Python Dex for experimental use.


## How to build and deploy
1. Clone this repository on your pc.
2. Clone the application's repository from "https://github.com/MGasiorowskii/CryptoCurrencyExchange" and place it here as "CryptoCurrencyExchange" 
3. Make the following changes in "CryptoCurrencyExchange/Exchange/Exchange/settings.py"

       change "SECRET_KEY = "..."" to "SECRET_KEY = os.environ.get("SECRET_KEY"). secrets shall not get commited in repositories.
       change "ALLOWED_HOSTS = []" to "ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',') if os.environ.get('ALLOWED_HOSTS') else []" so that its value could be passed as an environment variable.
       add "STATIC_ROOT = BASE_DIR / "staticfiles"" in order to serve static files seprately.
4. Build the docker image considering the version and push it to your docker registery.
        
       docker build -t dex:1.0.0 .
5. Create kubernetes name space 

       NAMESPACE="crypto-exchange"
       kubectl create namespace ${NAMESPACE}
6. Create the postgres secret which contains its authentication's data

       kubectl  -n ${NAMESPACE} create secret generic db-secret  \
       --from-literal=DATABASE_NAME="" \
       --from-literal=DATABASE_USER="" \
       --from-literal=DATABASE_PASSWORD=""
7. Deploy postgres, secrets and config maps, the app and its ingress. Deploy them following the order below: 

       kubectl -n ${NAMESPACE} apply -f Kuber/postgres.yaml
       kubectl -n ${NAMESPACE} apply -f Kuber/configmap-secret.yaml
       kubectl -n ${NAMESPACE} apply -f Kuber/app.yaml
       kubectl -n ${NAMESPACE} apply -f Kuber/ingress.yaml
8. <a name="access-app"></a>Now if "dex.local" has been defined in your dns server or hosts file, you can browse it and open the app.  

## Migrations
<p>Migrations should be done every time the new version has affected how data shall be stored in database.<br>
Same way they should be rollbacked when the app version is about to downgrade.<br>
In the current infrastructure migrations areis handled by a initcontainer which gets ran each time the app starts.<br>
As the muigrations are idompotent re-runnig them is not a big deal.</p>

## Access the app
<p>As mentioned 8th item of [How to build and deploy](#how-to-build-and-deploy), to access the application you<br>
should have the name <a href="http://dex.local">dex.local</a> defined in your DNS subsystem to point to the<br>
kubernetes cluster. this way you can browse to the dex and use it.</p>

## Backup and Restore
<p>Consider that out dex application is stateless and all the data is stored in postgres database.<br>
Thus it is important to supervision a continuous and work backup procedure, monitor it's integrity and<br>
plan the restore steps in case.In this section I describe the applied backup restore plan</p>

### Backup
<p>Backup databasae is </p>

### Restore

## Rollback

## Troubleshoot

## Limitations

## Production environment considerationsl