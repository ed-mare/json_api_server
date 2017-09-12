FROM ruby:2.3.3

ENV GEM_HOME /home/gems/mygem
RUN mkdir -p $GEM_HOME
# https://docs.docker.com/engine/reference/builder/#workdir
WORKDIR $GEM_HOME
COPY . $GEM_HOME
RUN bundle install
# RUN cd spec/test_app &&r rake db:migrate && rake db:migrate RAILS_ENV=test
