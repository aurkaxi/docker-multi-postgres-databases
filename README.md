# docker-multi-postgres-databases

Example for having [multiple Postgres databases with different passwords per db for a single docker container](https://www.amarjanica.com/docker-multiple-postgres-databases).

for `POSTGRES_MULTIPLE_DATABASES=db1,db2:usr2,db3::pass3,db4:usr4:pass4`

Database|User|Password|Logic
-|-|-|-
db1|`$POSTGRES_USER`|`$POSTGRES_PASSWORD`|No user/pass provided; falls back to globals.
db2|usr2|`$POSTGRES_PASSWORD`|User provided; password falls back to global.
db3|`$POSTGRES_USER`|pass3|User empty (double colon); password provided.
db4|usr4|pass4|All fields explicitly defined.

# Getting started
```
cp .env.example .env
docker compose up
```


[![](https://markdown-videos.deta.dev/youtube/UVBrRKgnJB4)](https://youtu.be/UVBrRKgnJB4)

