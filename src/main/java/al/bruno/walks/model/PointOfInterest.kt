package al.bruno.walks.model

data class PointOfInterest(
    val sys: Sys,
    val title: String,
    val description: String,
    val coordinate: Coordinate,
    val images: List<Asset>,
    val categories: List<Category>
) {
    val id: String get() = sys.id
}

