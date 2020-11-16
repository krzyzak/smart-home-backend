# Synopsis

This is a very simple application that periodically gathers various metrics and stores them in InfluxDB (which is later used in Grafana).
It consist of a few classes:

- `AirlyReadout` gathers Air Quality data from <a href="https://airly.com">Airly.com</a>
- `FibaroReadout` reads data from <a href="https://fibaro.com">Fibaro</a> sensors
- `NetatmoReadout` reads data from <a href="https://netatmo.com">Netatmo Weather station</a>
- `PVReadout` stores daily data from my PV sytem
- `SpeedtestReadout` logs speed of my internet connection
- `TauronReadout` fetches data from my electricity provider

# Usage

Application is fully dockerized. To build new image:
```docker build -t krzyzak/smart-home-backend```

To push it to a registry:

```docker push krzyzak/smart-home-backend:latest```

Don't forget to set all required ENV vars.
