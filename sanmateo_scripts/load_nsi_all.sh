psql -d sanmateo -f 1a-create_nsi_tables.sql
bash 1b-load_raw_nsi_data.sh
psql -d sanmateo -f 1c-index_fast_tables.sql
psql -d sanmateo -f 1d-sanity-checks.sql
psql -d sanmateo -f 2-create_aeb_tables.sql