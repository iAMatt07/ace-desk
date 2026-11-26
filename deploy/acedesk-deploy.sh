#!/bin/bash
# ACE Desk: aplica a versao do GitHub no container (chamado no boot da VM)
cd /opt/ace-desk || exit 1
for i in $(seq 1 60); do docker exec acedesk true 2>/dev/null && break; sleep 5; done
for d in app routes resources/views lang public; do
  [ -d "$d" ] && docker cp "$d/." "acedesk:/app/$d/"
done
docker exec acedesk sh -c 'cd /app && php artisan optimize:clear'
docker restart acedesk
echo ACE-DEPLOY-OK $(git log --oneline -1)
