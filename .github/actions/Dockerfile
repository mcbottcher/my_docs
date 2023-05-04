FROM sphinxdoc/sphinx

COPY . /home/my_docs/

WORKDIR /home/my_docs

RUN pip install -r docs/requirements.txt

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["cd docs && make html"]