from geoalchemy2.elements import WKTElement

MILES_TO_METERS = 1609.34


def point(latitude: float, longitude: float) -> WKTElement:
    return WKTElement(f"POINT({longitude} {latitude})", srid=4326)


def miles_to_meters(miles: float) -> float:
    return miles * MILES_TO_METERS


def meters_to_miles(meters: float) -> float:
    return meters / MILES_TO_METERS
