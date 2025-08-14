from typing import List, Optional
from models.routes import RouteConfig

def get_route_config(routes: List[RouteConfig], path: str) -> Optional[RouteConfig]:
    """Get route configuration by path."""
    return next((r for r in routes if r["path"] == path), None)

def get_route_by_index(routes: List[RouteConfig], index: int) -> Optional[RouteConfig]:
    """Get route configuration by index."""
    return next((r for r in routes if r["index"] == index), None)

def get_default_route(routes: List[RouteConfig]) -> RouteConfig:
    """Get the default route configuration."""
    return get_route_by_index(routes, 0) or routes[0]

def get_route_index(routes: List[RouteConfig], path: str) -> int:
    """Get the index of a route by path."""
    config = get_route_config(routes, path)
    return config["index"] if config else 0
