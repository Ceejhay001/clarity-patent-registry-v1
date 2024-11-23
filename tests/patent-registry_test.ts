import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register a new patent",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('patent-registry', 'register-patent', [
                types.uint(1),
                types.ascii("Test Patent"),
                types.utf8("Test Description"),
                types.uint(100)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Can pay royalties for a patent",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('patent-registry', 'register-patent', [
                types.uint(1),
                types.ascii("Test Patent"),
                types.utf8("Test Description"),
                types.uint(100)
            ], deployer.address),
            Tx.contractCall('patent-registry', 'pay-royalty', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
    }
});

Clarinet.test({
    name: "Only owner can deactivate patent",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('patent-registry', 'register-patent', [
                types.uint(1),
                types.ascii("Test Patent"),
                types.utf8("Test Description"),
                types.uint(100)
            ], deployer.address),
            Tx.contractCall('patent-registry', 'deactivate-patent', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr(types.uint(103)); // err-unauthorized
    }
});
