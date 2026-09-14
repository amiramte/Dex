kubectl exec -n crypto-exchange deploy/postgres -- ls -lh /backups

kubectl exec -n crypto-exchange deploy/postgres -- \
  pg_restore -U <DATABASE_USER> -d <DATABASE_NAME> \
  --clean --if-exists /backups/cryptoexchange_2026-09-14_02-00-00.dump
