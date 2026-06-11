# This script is used to update the NEON database with file releases
# This script is automated to run every 6 months and will update the local database
# as well as the s3 object with up-to-date data files.

# load relevant packages
library(here)
here::i_am('code/update-NEON-db.R')
library(magrittr)
library(neonstore)
library(arrow)

# set the relevant variables for updating the local database
streamsites=c("HOPB", "LEWI", "POSE", "CUPE",
              "GUIL", "KING", "MCDI", "LECO",
              "WALK", "MAYF", "ARIK", "BLUE",
              "PRIN", "BLDE", "COMO", "WLOU",
              "SYCA", "REDB", "MART", "MCRA",
              "BIGC", "TECR", "OKSR", "CARI")

db_path = here::here('data/database-files/')

dps = c("DP1.20120.001","DP1.20107.001","DP1.20190.001")

neon_download(product = dps,
              site = streamsites,
              dir = db_path)

neon_store(dir = here::here('data/database-files/'),
           site = streamsites,
           db = neon_db(dir = db_path, read_only = FALSE))

# create a temporary directory for the export parquet files
export_dir = file.path(tempdir(), 'parquet')

# export the local parquet file structure to the local database
neon_export_db(dir = export_dir,
               db = neon_db(dir = here::here('data/database-files/')))


s3_specs = readRDS(here::here('data/repo-objs/s3_specs.rds'))

s3 = arrow::s3_bucket(bucket = paste0(s3_specs$bucket,"/",s3_specs$prefix,"/"))

neon_sync_db(s3 = s3,
             dir = export_dir)

db_update_date = saveRDS(Sys.Date(), here::here('data/repo-objs/db_update_date.rds'))