FROM legionio/legion

COPY . /usr/src/app/lex-claude

WORKDIR /usr/src/app/lex-claude
RUN bundle install
