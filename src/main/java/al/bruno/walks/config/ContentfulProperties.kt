package al.bruno.walks.config

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "contentful")
data class ContentfulProperties(
    val graphqlUrl: String,
    val spaceId: String,
    val accessToken: String,
    val environment: String = "master",
    val defaultLocale: String = "en-US"
) {
    fun locale(): String = defaultLocale
    fun graphqlBaseUrl() = "$graphqlUrl$spaceId/environments/$environment"
}