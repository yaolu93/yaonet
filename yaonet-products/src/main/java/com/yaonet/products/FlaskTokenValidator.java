package com.yaonet.products;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Component
public class FlaskTokenValidator {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${flask.auth.base-url:http://localhost:5000/api}")
    private String flaskAuthBaseUrl;

    public boolean validate(String authorizationHeader, String userIdHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            return false;
        }
        if (userIdHeader == null || userIdHeader.isBlank()) {
            return false;
        }

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", authorizationHeader);
        HttpEntity<Void> entity = new HttpEntity<>(headers);

        String verifyUrl = flaskAuthBaseUrl + "/users/" + userIdHeader;
        try {
            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                verifyUrl,
                HttpMethod.GET,
                entity,
                new ParameterizedTypeReference<>() {}
            );
            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                return false;
            }
            Object id = response.getBody().get("id");
            return id != null && userIdHeader.equals(String.valueOf(id));
        } catch (RestClientException ex) {
            return false;
        }
    }
}
