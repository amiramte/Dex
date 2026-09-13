NAMESPACE="crypto-exchange"
kubectl create namespace ${NAMESPACE}
kubectl  -n ${NAMESPACE} create secret generic db-secret  --from-literal=DATABASE_NAME="dex-db" \
    --from-literal=DATABASE_USER="dex-db-user" --from-literal=DATABASE_PASSWORD="paSs-db-word-xed"

kubectl -n ${NAMESPACE} apply -f postgres.yaml





kubectl -n ${NAMESPACE} apply -f configmap-secret.yaml
kubectl -n ${NAMESPACE} apply -f app.yaml
kubectl -n ${NAMESPACE} apply -f ingress.yaml