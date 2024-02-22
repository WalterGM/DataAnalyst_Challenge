import pandas as pd
from configparser import ConfigParser
from sqlalchemy import create_engine
import os

if __name__ == "__main__":
    config_file = os.path.dirname(os.path.dirname(os.path.abspath(__name__))) + "\\resources\\constants.conf"
    config = ConfigParser()
    config.read(config_file)

    basePath = config['URLS'].get('BasePath')
    files = config['FILE_NAMES'].get("files").split(",")
    engine = create_engine('postgresql://postgres:admin@localhost/postgres')
    hdr = {'User-Agent':  'email@email.com'} ## fake email to send the http request

    for file in files:
        df_data = pd.read_csv(basePath + file, sep="\t", storage_options=hdr)
        ##removing tabulation from columns
        new_columns = {x: x.strip() for x in df_data.columns}
        df_data = df_data.rename(columns=new_columns)
        df_data.to_sql(file, engine, index=False, if_exists='append')
        print(f"{file} successfully load to database")
        ##remove from memory
        del(df_data)

