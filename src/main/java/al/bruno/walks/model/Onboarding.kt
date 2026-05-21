package al.bruno.walks.model

data class Onboarding(
    val sys: Sys,
    val title: String,
    val description: String,
    val order: Int,
    val androidImage: Asset
) {
    val id: String get() = sys.id
}
