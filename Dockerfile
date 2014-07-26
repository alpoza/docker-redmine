FROM jbbarth/ruby

MAINTAINER Jean-Baptiste BARTH <jeanbaptiste.barth@gmail.com>

#prerequisites
RUN apt-get update && apt-get upgrade -y #2014-07-26
RUN apt-get install -y wget git sudo

#postgres
RUN apt-get install -y postgresql-9.1 postgresql-server-dev-9.1
RUN sed -i '/TYPE.*DATABASE/a local  redmine  redmine  trust' /etc/postgresql/9.1/main/pg_hba.conf
RUN service postgresql start; sudo -u postgres createuser --no-createdb --no-superuser --no-createrole redmine; sudo -u postgres createdb -E UTF-8 -O redmine -T template0 redmine;

#redmine
RUN mkdir /app
WORKDIR /app
RUN git clone https://github.com/jbbarth/redmine-scripts
RUN /app/redmine-scripts/core_download.sh; mv redmine-2.5.1-blank redmine
RUN echo "production:\n  adapter: postgresql\n  database: redmine\n  username: redmine\n  password: \n  pool: 10\n\ndevelopment:\n  adapter: postgresql\n  database: redmine\n  username: redmine\n  password: " > /app/redmine/config/database.yml
RUN service postgresql start; /app/redmine-scripts/core_install.sh /app/redmine

#env for the following steps
WORKDIR /app/redmine
ENV PATH /usr/local/rvm/gems/ruby-2.0.0-p481@redmine/bin:/usr/local/rvm/gems/ruby-2.0.0-p481/bin:/usr/local/rvm/gems/ruby-2.0.0-p481@global/bin:/usr/local/rvm/rubies/ruby-2.0.0-p481/bin:$PATH
ENV GEM_PATH /usr/local/rvm/gems/ruby-2.0.0-p481@redmine:/usr/local/rvm/gems/ruby-2.0.0-p481@global
ENV GEM_HOME /usr/local/rvm/gems/ruby-2.0.0-p481@redmine

#passenger (rails app server)
RUN echo "gem 'passenger', '>= 4.0.48'" > /app/redmine/Gemfile.local
RUN bundle install
RUN passenger start --runtime-check-only #first start so it get's compiled.. else it will compile on 'docker run' which is not desired

#supervisord
RUN apt-get install -y supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#specific user
RUN useradd -N -M --gid rvm -d /app/redmine redmine
RUN chown -R redmine /app/redmine

#run
EXPOSE 3000

###VOLUME ["/mysql"]

CMD ["/usr/bin/supervisord"]
