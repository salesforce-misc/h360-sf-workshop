import { LightningElement } from 'lwc';
import listWidgets from '@salesforce/apex/HxlWidgetViewerController.listWidgets';
import getWidgetBody from '@salesforce/apex/HxlWidgetViewerController.getWidgetBody';

export default class HxlWidgetViewer extends LightningElement {
    widgets = [];
    selectedId;
    selectedName;
    widgetBody;          // parsed widgetBody object → fed to <c-mosaic-tile>
    widgetDescription;   // pithy one-liner read from the widget body ("code comment")
    rawJson = '';        // pretty-printed full contentBody
    activeTab = 'preview';
    listError;
    bodyError;
    loadingBody = false;

    connectedCallback() {
        this.loadList();
    }

    async loadList() {
        this.listError = undefined;
        try {
            this.widgets = await listWidgets();
        } catch (e) {
            this.listError = this.errMsg(e);
        }
    }

    get hasWidgets() {
        return this.widgets && this.widgets.length > 0;
    }

    // decorate list items with a selected-state css class
    get widgetItems() {
        return (this.widgets || []).map((w) => ({
            ...w,
            itemClass:
                'slds-item hxl-widget-item' +
                (w.id === this.selectedId ? ' hxl-widget-item_selected' : '')
        }));
    }

    get showPreview() {
        return this.activeTab === 'preview';
    }
    get showJson() {
        return this.activeTab === 'json';
    }
    get previewTabClass() {
        return this.tabClass('preview');
    }
    get jsonTabClass() {
        return this.tabClass('json');
    }
    tabClass(name) {
        return (
            'slds-tabs_default__item' +
            (this.activeTab === name ? ' slds-is-active' : '')
        );
    }

    get hasSelection() {
        return !!this.selectedId;
    }

    get hasDescription() {
        return !!this.widgetDescription;
    }

    // Body fed to the structural preview, with the description node stripped
    // (its text is lifted into the Description field, so don't render it twice).
    get renderBody() {
        const body = this.widgetBody;
        if (!body || !Array.isArray(body.children)) {
            return body;
        }
        const desc = this.descriptionNode(body);
        const children = body.children.filter((c) => c !== desc);
        return { ...body, children };
    }

    // Pull a human-readable "code comment" description from the widget body.
    // Convention: a leading top-level `tile/text` node with variant "caption" is
    // the widget's description (the server's strict schema forbids custom keys and
    // requires UUID ids, so a caption-variant sentinel is the portable carrier).
    // Falls back to contentBody.description if a future schema surfaces one.
    // No match → undefined → the Description field is hidden.
    readDescription(contentBody) {
        if (!contentBody) {
            return undefined;
        }
        if (typeof contentBody.description === 'string') {
            return contentBody.description;
        }
        const desc = this.descriptionNode(contentBody.widgetBody);
        return desc ? desc.attributes.text : undefined;
    }

    // The description node, if present: a top-level tile/text with variant "caption".
    descriptionNode(body) {
        const kids = (body && body.children) || [];
        return kids.find(
            (c) =>
                c &&
                c.definition === 'tile/text' &&
                c.attributes &&
                c.attributes.variant === 'caption' &&
                typeof c.attributes.text === 'string'
        );
    }

    async handleSelect(evt) {
        const id = evt.currentTarget.dataset.id;
        const name = evt.currentTarget.dataset.name;
        this.selectedId = id;
        this.selectedName = name;
        this.bodyError = undefined;
        this.widgetBody = undefined;
        this.widgetDescription = undefined;
        this.rawJson = '';
        this.loadingBody = true;
        try {
            const raw = await getWidgetBody({ contentId: id });
            const parsed = JSON.parse(raw);
            const contentBody =
                parsed && parsed.contentBody ? parsed.contentBody : parsed;
            this.rawJson = JSON.stringify(contentBody, null, 2);
            this.widgetBody =
                (contentBody && contentBody.widgetBody) || contentBody;
            this.widgetDescription = this.readDescription(contentBody);
        } catch (e) {
            this.bodyError = this.errMsg(e);
        } finally {
            this.loadingBody = false;
        }
    }

    showPreviewTab() {
        this.activeTab = 'preview';
    }
    showJsonTab() {
        this.activeTab = 'json';
    }
    handleRefresh() {
        this.loadList();
    }

    errMsg(e) {
        return (
            (e && e.body && e.body.message) ||
            (e && e.message) ||
            'Unknown error'
        );
    }
}
