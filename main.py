import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from rag_service.config.settings import settings
from rag_service.api import routes_resumes, routes_health, routes_admin, routes_agent, routes_ingestion, routes_jobs, routes_perf

logger = logging.getLogger(__name__)


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
    )

    # Add CORS middleware to handle cross-origin requests
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # In production, specify actual origins
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    api_prefix = settings.api_prefix

    app.include_router(routes_health.router, prefix=api_prefix)
    app.include_router(routes_resumes.router, prefix=api_prefix)  # Only GET /resumes/{id}
    app.include_router(routes_jobs.router, prefix=api_prefix)  # GET /jobs/{id} and POST /search/jobs
    app.include_router(routes_admin.router, prefix=api_prefix)
    app.include_router(routes_agent.router, prefix=api_prefix)  # Agent-enhanced search endpoints
    app.include_router(routes_ingestion.router, prefix=api_prefix)  # File upload ingestion endpoints
    app.include_router(routes_perf.router, prefix=api_prefix)  # Performance debugging endpoints

    @app.middleware("http")
    async def catch_exceptions_middleware(request, call_next):
        try:
            response = await call_next(request)
            return response
        except BrokenPipeError:
            # Silently handle broken pipe errors
            logger.warning(f"[API] Broken pipe error for {request.url.path}")
            # Return a minimal response
            from fastapi.responses import JSONResponse
            return JSONResponse(
                status_code=200,
                content={"error": "Connection closed by client"}
            )
        except Exception as e:
            logger.error(f"[API] Unhandled exception: {str(e)}", exc_info=True)
            raise

    return app


app = create_app()
