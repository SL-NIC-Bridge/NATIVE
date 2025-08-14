from typing import TypedDict

class RouteConfig(TypedDict):
    """Type definition for route configuration.
    
    Attributes:
        path: The URL path for the route
        title: The display title of the route
        icon: The icon to show when the route is not selected
        selected_icon: The icon to show when the route is selected
        label: The text label for the route
        index: The numerical index of the route in the navigation
    """
    path: str
    title: str
    icon: str
    selected_icon: str
    label: str
    index: int
