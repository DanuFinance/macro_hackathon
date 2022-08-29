# Written for Danu, 2022


import argparse
import datetime
import functools
import logging
import re

import flask
import flask_scss
import waitress
import werkzeug

import appraisal


def route_marketplace():
    return flask.render_template("marketplace.html")


@functools.cache
def route_errors(error: werkzeug.exceptions.HTTPException):
    """General-purpose error handler for all exceptions that the end-user may encounter"""

    # Convert CamelCase Error class names to something the end-user can understand
    class_name: str = re.sub(r"((?<=[a-z])[A-Z]|(?<!\A)[A-Z](?=[a-z]))", r" \1", error.__class__.__name__)

    return flask.render_template("errors.html", error = error, message = "—" + class_name)


def route_appraisal(address: str, token_ID: str):
    """Router for price lookups, both via API as well as web browser"""

    match subdomain:

        case "www":
           route_errors(werkzeug.exceptions.NotFound(description = "Appraisal front-end not yet implemented"))

        case "api":

            # Turned automatically into JSON, see stackoverflow.com/a/58917715
            return {
                "message_type": "price_update",
                "message_payload": appraisal.appraise(address, token_ID),
                # In RFC 3339 format, see stackoverflow.com/a/{27987813, 39079819}
                "time": datetime.datetime.now(datetime.timezone.utc).astimezone().isoformat()
            }


if __name__ == "__main__":

    # Instantiate global app
    app = flask.Flask(__name__, static_folder = "static", static_url_path = "/")

    # Parse arguments
    parser = argparse.ArgumentParser(description = "Danu hackathon technical demonstration")
    parser.add_argument("--host", default = "0.0.0.0")
    parser.add_argument("--port", default = 8000)
    parser.add_argument("--threads", default = 4)
    parser.add_argument("-l", "--logging-level", default = 3, action = "store_true")
    parser.add_argument("-d", "--development-mode", default = False, action = "store_true")
    args: argparse.Namespace = parser.parse_args()

    # Register routes without decorators
    app.route("/marketplace")(route_marketplace)
    app.errorhandler(werkzeug.exceptions.HTTPException)(route_errors)
    app.route("/appraise/<address>/<token_ID>", subdomain = "<subdomain>", methods = ["GET"])(route_appraisal)

    # Production-ready logging
    logger: logging.Logger = logging.getLogger("waitress")
    logger.setLevel(args.logging_level)

    # Configure automatic reloading of templates and recompilation of SCSS if in development mode
    if args.development_mode:
        app.testing = True
        app.config["TEMPLATES_AUTO_RELOAD"] = True
        flask_scss.Scss(app, asset_dir = "./scss", static_dir = "./static/css")

    # Set-up the server and finalize
    waitress.serve(app, host=args.host, port = args.port, threads = args.threads)

