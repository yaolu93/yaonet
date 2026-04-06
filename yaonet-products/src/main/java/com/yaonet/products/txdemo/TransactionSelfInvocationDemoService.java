package com.yaonet.products.txdemo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Service
public class TransactionSelfInvocationDemoService {

    private static final Logger log = LoggerFactory.getLogger(TransactionSelfInvocationDemoService.class);

    private final ObjectProvider<TransactionSelfInvocationDemoService> selfProvider;

    public TransactionSelfInvocationDemoService(ObjectProvider<TransactionSelfInvocationDemoService> selfProvider) {
        this.selfProvider = selfProvider;
    }

    @Transactional
    public void transactionalMethod(String caller) {
        boolean txActive = TransactionSynchronizationManager.isActualTransactionActive();
        log.info("[TX-DEMO] transactionalMethod caller={} txActive={}", caller, txActive);
    }

    public void internalSelfInvocation() {
        boolean txActiveBefore = TransactionSynchronizationManager.isActualTransactionActive();
        log.info("[TX-DEMO] internalSelfInvocation before this.call txActive={}", txActiveBefore);
        this.transactionalMethod("internal-this-call");
    }

    public void callViaProxyFromSameBean() {
        boolean txActiveBefore = TransactionSynchronizationManager.isActualTransactionActive();
        log.info("[TX-DEMO] callViaProxyFromSameBean before proxy.call txActive={}", txActiveBefore);
        selfProvider.getObject().transactionalMethod("self-provider-proxy-call");
    }

    // Case 4: public method calls a private @Transactional method
    // CGLIB subclass cannot override private methods (Java visibility rule),
    // so the proxy never wraps privateTransactionalMethod → @Transactional is silently ignored.
    public void publicCallsPrivate() {
        boolean txActiveBefore = TransactionSynchronizationManager.isActualTransactionActive();
        log.info("[TX-DEMO] publicCallsPrivate before calling private method txActive={}", txActiveBefore);
        privateTransactionalMethod();
    }

    @Transactional  // ← has ZERO effect: CGLIB cannot override a private method
    private void privateTransactionalMethod() {
        boolean txActive = TransactionSynchronizationManager.isActualTransactionActive();
        log.info("[TX-DEMO] privateTransactionalMethod txActive={} (expected false: proxy cannot intercept private)", txActive);
    }
}