package al.bruno.walks.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.reactive.function.client.WebClient

@Configuration
class WebClientConfig(private val props: ContentfulProperties) {
    @Bean
    fun contentfulWebClient(): WebClient {
        return WebClient
            .builder()
            .baseUrl(props.graphqlBaseUrl())
            .defaultHeader("Authorization", "Bearer ${props.accessToken}")
            .defaultHeader("Content-Type", "application/json")
//            .codecs { it.defaultCodecs().maxInMemorySize(5 * 1024 * 1024) }
            .build()
    }
}
