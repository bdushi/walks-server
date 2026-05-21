package al.bruno.walks.model

data class Region(
    val sys: Sys,
    val title: String,
    val description: String,
    val coordinate: Coordinate,
    val image: Asset,
    val pointOfInterests: List<PointOfInterest>,
    val popularPointOfInterests: List<PointOfInterest>,
    val tours: List<Tour>
) {
    val id: String get() = sys.id
}

