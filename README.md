# music-catalog

Pre-requirements:

1. Install MongoDB, Ruby and Clementine
2. Run command: `sudo apt install --no-install-recommends bpm-tools`
3. Run command: `bundle install`
4. Create file `config.json` from the template: `cp config-example.json config.json`
5. Run `sudo systemctl start mongod` or `sudo service mongo start`
6. For mp3gain installed as snap you have to run this: `snap connect mp3gain:removable-media`
