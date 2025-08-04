from flask import Flask, jsonify, json, render_template, request, url_for, redirect, flash
from werkzeug.exceptions import abort
import logging
import sys
import os
import uuid
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.sqlite3 import SQLite3Instrumentor
from opentelemetry.instrumentation.psycopg2 import Psycopg2Instrumentor
from opentelemetry.sdk.resources import Resource

# Add current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import PostgreSQL configuration and models
from config import app, db
from models import posts

# Configure tracing with proper resource attributes
resource = Resource.create({
    "service.name": os.getenv("OTEL_SERVICE_NAME", "rantzapp"),
    "service.version": os.getenv("OTEL_SERVICE_VERSION", "1.0.0"),
    "service.instance.id": str(uuid.uuid4())
})

trace.set_tracer_provider(TracerProvider(resource=resource))
tracer = trace.get_tracer(__name__)

# Configure OTLP exporter with proper endpoint
otlp_endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://otel-collector-opentelemetry-collector.observability.svc.cluster.local:4317")
otlp_exporter = OTLPSpanExporter(
    endpoint=otlp_endpoint,
    insecure=True
)

# Configure the trace processor
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Instrument Flask and database
FlaskInstrumentor().instrument_app(app)
SQLite3Instrumentor().instrument()
Psycopg2Instrumentor().instrument()


#connection count
db_connection_count = 0

# Configure logging
def configure_logging(log_level=logging.INFO, log_format='%(asctime)s - %(levelname)s - %(message)s'):
    """Configures logging to both stdout and stderr.

    Args:
        log_level (int, optional): The minimum severity level for logging. Defaults to logging.INFO.
        log_format (str, optional): The format string for log messages. Defaults to '%(asctime)s - %(levelname)s - %(message)s'.
    """

    stdout_handler = logging.StreamHandler(sys.stdout)
    stderr_handler = logging.StreamHandler(sys.stderr)

    formatter = logging.Formatter(log_format)
    stderr_handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.setLevel(log_level)
    root_logger.addHandler(stdout_handler)
    root_logger.addHandler(stderr_handler)

# Function to get a post using its ID
def get_post(post_id):
    global db_connection_count
    db_connection_count += 1
    post = posts.query.get(post_id)
    return post

# Define the Flask application
# app = Flask(__name__)  # Remove this line since app is imported from config
app.config['SECRET_KEY'] = 'your secret key'
configure_logging()

# Define the main route of the web application 
@app.route('/')
def index():
    with trace.get_tracer(__name__).start_as_current_span("home-page") as span:
        all_posts = posts.query.order_by(posts.created.desc()).all()
        tracking_id = str(uuid.uuid4())
        span.set_attribute("tracking_id", tracking_id)
        logging.info("The homepage has been retrieved.")
        return render_template('index.html', posts=all_posts)

# Define how each individual article is rendered 
# If the post ID is not found a 404 page is shown
@app.route('/<int:post_id>')
def post(post_id):
    post = get_post(post_id)
    if post is None:
        logging.warning("404: Requested article not found")
        return render_template('404.html'), 404
    else:
        logging.info("Article retrieved: {}".format(post.title))
        return render_template('post.html', post=post)
      

# Define the About Us page
@app.route('/about')
def about():
    logging.info("About Us page retrieved")
    return render_template('about.html')

# Define the post creation functionality 
@app.route('/create', methods=('GET', 'POST'))
def create():
    if request.method == 'POST':
        name = request.form['name']
        title = request.form['title']
        content = request.form['content']

        if not title:
            flash('Title is required!')
        elif not name:
            flash('Name is required!')
        else:
            new_post = posts(name=name, title=title, content=content)
            db.session.add(new_post)
            db.session.commit()
            logging.info("New article created: {} by {}".format(title, name))

            return redirect(url_for('index'))

    return render_template('create.html')

@app.route('/healthz')
def health():
    return jsonify({"result": "OK - healthy"}), 200

@app.route('/metrics')
def metrics():

    post_count = posts.query.count()

    response = {
        'post_count': post_count,
        'db_connection_count': db_connection_count
    }
    return jsonify(response), 200



# start the application on port 3111
if __name__ == "__main__":
   app.run(host='0.0.0.0', port='3111', debug=True)

