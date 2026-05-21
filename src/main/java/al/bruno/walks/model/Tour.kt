package al.bruno.walks.model

data class Tour(
    val sys: Sys,
    val title: String,
    val description: String,
    val coordinate: Coordinate,
    val pointOfInterests: List<PointOfInterest>
) {
    val id: String get() = sys.id
}

