package al.bruno.walks

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.context.properties.ConfigurationPropertiesScan
import org.springframework.boot.runApplication
import org.springframework.cache.annotation.EnableCaching

@EnableCaching
@SpringBootApplication
@ConfigurationPropertiesScan
//@EnableConfigurationProperties(ContentfulProperties::class)
class WalksApp

fun main(args: Array<String>) {
    runApplication<WalksApp>(*args)
}