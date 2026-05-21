package al.bruno.walks.model

data class AudioGuide(
    val sys: Sys,
    val title: String,
    val text: String,
    val audios: List<Audio>,
    val image: Asset
) {
    val id: String get() = sys.id
}
