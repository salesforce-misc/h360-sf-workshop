import { LightningElement, api } from 'lwc';

/**
 * Renderer LWC for the OrderStatusCard Custom Lightning Type (Surface #3).
 * Renders OrderStatusSkill.Response as a rich card inside the agent conversation.
 * CLT renderers receive the typed value via the `value` @api property.
 */
export default class OrderStatusCard extends LightningElement {
    @api value;

    get orderNumber() {
        return this.value?.orderNumber;
    }
    get status() {
        return this.value?.status;
    }
    get owner() {
        return this.value?.owner;
    }
    get summary() {
        return this.value?.summary;
    }
    get availableAction() {
        return this.value?.availableAction;
    }
    get found() {
        return this.value?.found === true;
    }
    get hasAction() {
        return Boolean(this.value?.availableAction);
    }

    handleAction() {
        // Emits the chosen action for the host (agent surface) to route.
        this.dispatchEvent(
            new CustomEvent('action', {
                detail: { orderNumber: this.orderNumber, action: this.availableAction }
            })
        );
    }
}
