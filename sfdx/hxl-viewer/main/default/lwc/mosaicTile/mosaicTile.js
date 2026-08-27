import { LightningElement, api } from 'lwc';

const TEXT_VARIANT_CLASS = {
    h1: 'slds-text-heading_large',
    h2: 'slds-text-heading_medium',
    h3: 'slds-text-heading_small',
    h4: 'slds-text-title_caps',
    body: 'slds-text-body_regular',
    caption: 'slds-text-body_small'
};

export default class MosaicTile extends LightningElement {
    @api node;

    get def() {
        return (this.node && this.node.definition) || '';
    }
    get attrs() {
        return (this.node && this.node.attributes) || {};
    }
    // children decorated with a stable key for the for:each
    get kids() {
        const children = (this.node && this.node.children) || [];
        return children.map((c, i) => ({
            node: c,
            key: (c && c.id) || 'k' + i
        }));
    }
    get hasKids() {
        return this.kids.length > 0;
    }

    // --- leaf types -------------------------------------------------------
    get isText() {
        return this.def === 'tile/text';
    }
    get text() {
        return this.attrs.text;
    }
    get textClass() {
        const v = this.attrs.variant || 'body';
        return (
            (TEXT_VARIANT_CLASS[v] || 'slds-text-body_regular') + ' hxl-text'
        );
    }
    get isButton() {
        return this.def === 'tile/button';
    }
    get buttonLabel() {
        return this.attrs.label || this.attrs.text || 'Button';
    }
    get isBadge() {
        return this.def === 'tile/badge';
    }
    get badgeText() {
        return this.attrs.text || this.attrs.label;
    }
    get isSeparator() {
        return this.def === 'tile/separator';
    }
    get isIcon() {
        return this.def === 'tile/icon';
    }
    get iconName() {
        return this.attrs.name || this.attrs.iconName || 'icon';
    }
    get isMarkdown() {
        return this.def === 'tile/markdown';
    }
    get markdownSource() {
        return this.attrs.source || this.attrs.text || '';
    }
    get isLink() {
        return this.def === 'tile/link';
    }
    get linkText() {
        return this.attrs.text || this.attrs.label || this.attrs.href || 'link';
    }
    get linkHref() {
        return this.attrs.href || '#';
    }

    // --- callout (header + optional children) -----------------------------
    get isCallout() {
        return this.def === 'tile/callout';
    }
    get calloutTitle() {
        return this.attrs.title;
    }
    get calloutDescription() {
        return this.attrs.description;
    }

    // --- container types (wrapper + children) -----------------------------
    get isContainer() {
        return [
            'tile/widget',
            'tile/row',
            'tile/column',
            'tile/container',
            'tile/card',
            'tile/list',
            'tile/listitem',
            'tile/accordion'
        ].includes(this.def);
    }
    get containerClass() {
        switch (this.def) {
            case 'tile/row':
                return 'slds-grid slds-gutters slds-wrap hxl-block hxl-row';
            case 'tile/card':
                return 'hxl-block hxl-card';
            case 'tile/list':
                return 'hxl-block hxl-list';
            case 'tile/listitem':
                return 'hxl-block hxl-listitem';
            case 'tile/accordion':
                return 'hxl-block hxl-accordion';
            case 'tile/column':
            case 'tile/widget':
            case 'tile/container':
            default:
                return 'slds-grid slds-grid_vertical hxl-block hxl-col';
        }
    }

    // --- accordion item (header: title/icon/subtitle + children) ----------
    // Spec definition is `tile/accordionitem`; payloads seen in the wild also
    // use `tile/accordionItem` — match case-insensitively so neither slips
    // through to the "unsupported" branch.
    get isAccordionItem() {
        return this.def.toLowerCase() === 'tile/accordionitem';
    }
    get accordionTitle() {
        return this.attrs.title;
    }
    get accordionSubtitle() {
        return this.attrs.subtitle;
    }
    get accordionIconName() {
        return this.attrs.iconName;
    }
    // read-only structural view shows children regardless; the caret just
    // reflects the authored initial state (isExpanded, default false).
    get accordionCaret() {
        return this.attrs.isExpanded ? '▾' : '▸';
    }

    // --- unknown ----------------------------------------------------------
    get isKnown() {
        return (
            this.isText ||
            this.isButton ||
            this.isBadge ||
            this.isSeparator ||
            this.isIcon ||
            this.isMarkdown ||
            this.isLink ||
            this.isCallout ||
            this.isContainer ||
            this.isAccordionItem
        );
    }
    get isUnknown() {
        return !!this.def && !this.isKnown;
    }
    get isEmptyNode() {
        return !this.def;
    }
    get unknownLabel() {
        return this.def;
    }
    get attrsJson() {
        try {
            return JSON.stringify(this.attrs, null, 2);
        } catch (e) {
            return '{}';
        }
    }
}
