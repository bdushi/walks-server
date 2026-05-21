package al.bruno.walks.model

data class Category(
    val sys: Sys,
    val name: String,
    val key: String,
    val icon: Asset,
    val mapMarker: Asset,
    val visitedMapMarker: Asset,
    val sideBarColor: String
) {
    val id: String get() = sys.id
}

