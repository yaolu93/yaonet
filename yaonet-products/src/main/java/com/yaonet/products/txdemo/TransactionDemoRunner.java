package com.yaonet.products.txdemo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.aop.support.AopUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "tx.demo.enabled", havingValue = "true")
public class TransactionDemoRunner implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(TransactionDemoRunner.class);

    private final TransactionSelfInvocationDemoService demoService;
    private final ApplicationContext applicationContext;

    @Value("${tx.demo.exit-on-finish:true}")
    private boolean exitOnFinish;

    public TransactionDemoRunner(
        TransactionSelfInvocationDemoService demoService,
        ApplicationContext applicationContext
    ) {
        this.demoService = demoService;
        this.applicationContext = applicationContext;
    }

    @Override
    public void run(ApplicationArguments args) {
        log.info("[TX-DEMO] ===== Transaction Proxy Demo Start =====");
        log.info("[TX-DEMO] Bean class={}", demoService.getClass().getName());
        log.info("[TX-DEMO] Is AOP proxy={}", AopUtils.isAopProxy(demoService));

        log.info("[TX-DEMO] Case 1: external call -> transactionalMethod (should be txActive=true)");
        demoService.transactionalMethod("external-runner-call");

        log.info("[TX-DEMO] Case 2: same bean via selfProvider proxy call (should be txActive=true)");
        demoService.callViaProxyFromSameBean();

        log.info("[TX-DEMO] Case 3: same bean this.call (self-invocation, should be txActive=false)");
        demoService.internalSelfInvocation();

        log.info("[TX-DEMO] Case 4: @Transactional on private method (should be txActive=false: CGLIB cannot override private)");
        demoService.publicCallsPrivate();

        log.info("[TX-DEMO] ===== Transaction Proxy Demo End =====");

        if (exitOnFinish) {
            int code = SpringApplication.exit(applicationContext, () -> 0);
            System.exit(code);
        }
    }
}