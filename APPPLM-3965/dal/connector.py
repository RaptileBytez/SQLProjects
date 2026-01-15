from sqlalchemy import create_engine
import oracledb

class OracleConnector:
    """Class to create SQLAlchemy engine for Oracle database connections."""
    def __init__(self):
        self.engine = None

    def get_oracle_engine(self, username: str, password: str, host: str, port: int, service_name: str):
        """
        Create a SQLAlchemy engine for connecting to an Oracle database.

        :param username: Database username
        :param password: Database password
        :param host: Database host
        :param port: Database port
        :param service_name: Database service name
        :return: SQLAlchemy engine instance
        """
        dsn = oracledb.makedsn(host, port, service_name=service_name)
        engine_url = f"oracle+oracledb://{username}:{password}@{dsn}"
        self.engine = create_engine(engine_url)
        return self.engine

    def get_oracle_engine_sid(self, username: str, password: str, host: str, port: int, sid: str):
        """
        Create a SQLAlchemy engine for connecting to an Oracle database using SID.

        :param username: Database username
        :param password: Database password
        :param host: Database host
        :param port: Database port
        :param sid: Database SID
        :return: SQLAlchemy engine instance
        """
        dsn = oracledb.makedsn(host, port, sid=sid)
        engine_url = f"oracle+oracledb://{username}:{password}@{dsn}"
        self.engine = create_engine(engine_url)
        return self.engine
