# Dex
Dejango/Python Dex for experimental use.


## How to build and deploy (CI/CD)
1. Clone this repository on your pc.
2. Clone the application's repository from "https://github.com/MGasiorowskii/CryptoCurrencyExchange" and place it here as "CryptoCurrencyExchange" 
3. Make the following changes in "CryptoCurrencyExchange/Exchange/Exchange/settings.py"

       change "SECRET_KEY = "..."" to "SECRET_KEY = os.environ.get("SECRET_KEY"). secrets shall not get commited in repositories.
       change "ALLOWED_HOSTS = []" to "ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',') if os.environ.get('ALLOWED_HOSTS') else []" so that its value could be passed as an environment variable.
       add "STATIC_ROOT = BASE_DIR / "staticfiles"" in order to serve static files seprately.
4. The requirements.txt files should be checked. Its has dependencies and their appropriate versions for python 3.9 (which is used by the developer).
5. Build the docker image considering the version and push it to your docker registery.
        
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
Database backup is acquired by a cronjob defined in kubernetes which tries to :
1. Backup database everyday on 2:00 am using pg_dump
2. put it in a timestamped file in tar format and in a different volume than original database volume.
3. Verify its correctness and integrity.
This job is deployed using bellowing comman :

       kubectl -n ${NAMESPACE} apply -f Kuber/backup.yaml
### Restore
To restore your data in a new database first list available backups (dumps) :

    kubectl exec -n $NAMESPACE deploy/postgres -- ls -lh /backups

then select the desired dump file and restore it as bellow :

    kubectl exec -n crypto-exchange deploy/postgres -- pg_restore -U <DATABASE_USER> -d <DATABASE_NAME> --clean --if-exists /backups/<DUMP_FILE>


## Rollback
As the app is deployed as a deployment, in case of need, one can easily rollback to an earlier version  using kubernetes rollout feature.
To see available revision history do as bellow :

    kubectl rollout history deployment/dex -n crypto-exchange
then you can migrate to an older revision using this command :

    kubectl rollout undo deployment/dex -n crypto-exchange --to-revision=3
and using this command you can chech the rollback status

    kubectl rollout status deployment/dex -n crypto-exchange
Don't worry about migrations as they are integrated in the deployment and are reran in each rollback. 

## Troubleshoot

### Scenario 1 - Error 502
This error means that the ingress is (almost) working fine and successfully reached the service behind it
but the service and the app behind it cannot serve fine. The possible items to check are listed :
1. Confirm that deployment is done successfully. Make sure that initcontainers are done successfully. pods are not
stock in a not proper state like :  CrashLoopBackOff, ImagePullBackOff, or 0/1 Ready
2. Check the containers' logs to find a promising issue, maybe bad migrations, wrong secrets or bind ports/addresses.
3. View ingress logs to see what upstream is actually called and review the services' endpoints to match the live pods sockets. 

### Senario 2 - Postgres heavy traffic
In case of continuous delays in database's responses first you should confirm that the problem is caused by high request counts. All these queries can be ran from the postgres pod using

    psql -U <DATABASE_USER> -d <DATABASE_NAME>
or from host using 
    
    kubectl exec -it deploy/postgres -n crypto-exchange -- psql -U <DATABASE_USER> -d <DATABASE_NAME>")
1. The database activity could be extracted by

       "SELECT count(*), state, application_name FROM pg_stat_activity GROUP BY state, application_name ORDER BY count(*) DESC;"

2. Then you can investigate the rate of stuck or long-running request

       "SELECT pid, now() - query_start AS duration, state, query FROM pg_stat_activity WHERE state != 'idle' ORDER BY duration DESC LIMIT 10;"
3. Check max_connections versus current usage

       # max connections count
       kubectl exec -it deploy/postgres -n crypto-exchange -- psql -U <DATABASE_USER> -d <DATABASE_NAME> -c "SHOW max_connections;"
       # current connections
       SELECT count(*) FROM pg_stat_activity;
4. View postgres resources usage

       kubectl top pod -n crypto-exchange -l app=postgres

5. Find out how many server processes (gunicorn) are running. they may cause the problem in case of multithread running with no proper pooling behavior.
  
       kubectl exec -it deploy/dex -n crypto-exchange -c app -- ps aux | grep gunicorn
base on what you found above, these actions could be done
1. Expand the database's resources 
2. Set CONN_MAX_AGE in Django's DATABASES settings to reuse connections instead of opening one for each request.
3. Introduce connection pooling between the app and Postgres.
4. Investigate the specific slow queries and optimize them.

## Limitations and Production environment considerations
### Infrastructure
1. The desing is for a single node kubernetes cluster. its better to have a multi node cluster.
2. A cloudnative or network storage is needed for multinode cluster and stability.
3. Secrets are better to be stored in a secret manager rather than in kubernetes cluster it self.
4. Network policies inside the cluster are a must.
5. Resources and replicas autoscaling.
### Application
1. App must deployed in more instances and separated in different nodes.
2. Allowed Hosts should be precisely determined.
3. TLS (or mutual TLS) connection between app parts (dex, database, ...).
4. Serving static files outside the pod for example by a objectstorage + ingress.
5. Init containers in multiple replicas could cause problems.
6. Python dependencies should be well identified and compatibility checked. 
### Database
1. Single instance database. It can be clustered for HA and better performance.
2. Backups are stored in same storage. Its better to have them on an external storage.
3. Automated restore testing.
4. Connection pooling ability is mandatory for performance optimization.
