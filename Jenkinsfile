buildWebService(
    postPush: {
        if (TAG == "master") {
            parallelCall (
                nodeLabels: ["web"],
                procedure: { nodeLabels ->
                    sh "sudo -n /sbin/stop rsyslog-docker"
                    sh "sudo -n /sbin/start rsyslog-docker"
                    "docker-registry.intr/webservices/rsyslog:$TAG deployed to web."
                })
        }
    }
)
