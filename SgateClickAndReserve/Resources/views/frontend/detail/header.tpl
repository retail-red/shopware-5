{extends file="parent:frontend/detail/header.tpl"}

{block name='frontend_index_header_javascript_tracking'}
    {$smarty.block.parent}
    {block name='frontend_index_header_javascript_tracking_rerail_red'}
        {if $rrConfig.displayType != 'disabled'}
            {block name='frontend_index_header_javascript_tracking_rerail_red_libary'}
                <script async type='text/javascript'
                        src='https://cdn.retail.red/omni/retailred-storefront-library-v3.js'></script>
            {/block}
            {block name='frontend_index_header_javascript_tracking_rerail_red_javascript'}
                <script>
                    try {
                        window.addEventListener('load', function () {
                            var localization = {$rrConfig.translations|default:null|json_encode} || {};
                            localization.countries = {$rrConfig.countriefs|default:["de"]|json_encode};
                            if (!Array.isArray(localization.countries)) {
                                localization.countries = [localization.countries];
                            }

                            var variants = {$sArticle.sConfigurator|json_encode} || [];
                            var hasVariants = !!variants.length;
                            var selectedVariants = variants.filter(function (variant) {
                                return variant.selected === true;
                            }) || [];
                            var isVariantSelected = !!selectedVariants.length;

                            var retailred = window.RetailRedStorefront.create({
                                apiKey: '{$rrConfig.apiKey}',
                                apiStage: '{$rrConfig.apiStage}',
                                useGeolocationImmediately: {$rrConfig.useGeolocationImmediately|json_encode},
                                saveCustomerData: '{$rrConfig.saveCustomerData}' === 'consentManager' ? ($.getCookiePreference('allow_local_storage') ? 'on' : 'off') : '{$rrConfig.saveCustomerData}',
                                browserHistory: {$rrConfig.browserHistory|json_encode},
                                testMode: {$rrConfig.testMode|json_encode},
                                unitSystem: '{$rrConfig.unitSystem}',
                                localization: localization,
                                inventory: {
                                    hideNumber: {$rrConfig.inventoryHideNumber|json_encode},
                                    showExactUntil: {$rrConfig.inventoryShowExactUntil|default:null|json_encode},
                                    showLowUntil: {$rrConfig.inventoryShowLowUntil},
                                },
                                legal: {
                                    terms: {$rrConfig.termsLink|default:null|json_encode},
                                    privacy: {$rrConfig.privacyLink|default:null|json_encode},
                                },
                                customer: {
                                    code: {$userData.additional.user.customernumber|json_encode},
                                    firstName: {$userData.additional.user.firstname|json_encode},
                                    lastName: {$userData.additional.user.lastname|json_encode},
                                    phone: {$userData.additional.user.phone|json_encode},
                                    emailAddress: {$userData.additional.user.email|json_encode},
                                },
                                ui: {
                                    reserveButtonClasses: {$rrConfig.reserveButtonClasses|default:null|json_encode},
                                },
                                product: {
                                    code: (!hasVariants || (hasVariants && isVariantSelected)) ? {if $rrConfig.productCodeMapping == 'ean'}{$sArticle.ean|json_encode}{else}{$sArticle.ordernumber|json_encode}{/if} : null,
                                    name: {$sArticle.articleName|json_encode},
                                    quantity: 1,
                                    imageUrl: {block name='frontend_index_header_javascript_tracking_rerail_red_javascript_image'}'{$sArticle.image.source}'{/block},
                                    price: {$sArticle.price_numeric},
                                    currencyCode: '{$Shop->getCurrency()->getCurrency()}',
                                    identifiers: {
                                        ean: {$sArticle.ean|json_encode},
                                    },
                                    options: selectedVariants.map(function (variant) {
                                        return {
                                            code: variant.groupID.toString(),
                                            name: variant.groupname,
                                            value: {
                                                code: variant.values[variant.selected_value].optionID.toString(),
                                                name: variant.values[variant.selected_value].optionname
                                            }
                                        };
                                    })
                                },
                            });

                            var render = function () {
                                {if $rrConfig.displayType == 'reserveButton'}
                                retailred.renderReserveButton('#rr-reserve-button');
                                {elseif $rrConfig.displayType == 'liveInventory'}
                                retailred.renderLiveInventory('#rr-live-inventory', {
                                    variant: '{$rrConfig.renderLiveInventoryMode}'
                                });
                                {/if}
                            }

                            render();

                            $(document).on('change', '#sQuantity', function () {
                                retailred.updateConfig({
                                    product: {
                                        quantity: parseInt($(this).val()),
                                    },
                                });
                            });

                            {block name='frontend_index_header_javascript_tracking_rerail_red_javascript_ajax_variant'}
                            $.subscribe('plugin/swAjaxVariant/onRequestData', function (e, me, response, values) {
                                try {
                                    var $response = $($.parseHTML(response, document));
                                    var ean = $.trim($response.find('meta[itemprop^=gtin]').attr('content'));

                                    {if $rrConfig.productCodeMapping == 'ean'}
                                    var productCode = ean;
                                    {else}
                                    var productCode = $.trim(me.$el.find(me.opts.orderNumberSelector).text());
                                    {/if}

                                    var newData = {
                                        quantity: 1,
                                        code: productCode,
                                        identifiers: {
                                            ean: ean,
                                        }
                                    };

                                    var newImg = me.$el.find('.product--image-container img').get(0);
                                    if (newImg) {
                                        newData.imageUrl = newImg.src;
                                    }

                                    var newName = me.$el.find('.product--title[itemprop="name"]').first().text();
                                    if (newName) {
                                        newData.name = newName.replace(/\s+/g, " ").trim();
                                    }

                                    var newPrice = me.$el.find('.price--content meta[itemprop=price]').attr('content');
                                    if (newPrice) {
                                        newData.price = parseFloat(newPrice);
                                    }

                                    var newVariant = variants.map(function (variant) {
                                        {literal}
                                        var selected_value = values[`group[${variant.groupID}]`]
                                        {/literal}

                                        if (!selected_value) {
                                            return null;
                                        }

                                        return {
                                            code: variant.groupID.toString(),
                                            name: variant.groupname,
                                            value: {
                                                code: variant.values[selected_value].optionID.toString(),
                                                name: variant.values[selected_value].optionname
                                            }
                                        };
                                    }).filter(Boolean);

                                    isVariantSelected = newVariant.length === variants.length;

                                    if (newImg) {
                                        newData.options = newVariant;
                                    }

                                    if (hasVariants && !isVariantSelected) {
                                        newData.code = null;
                                    }

                                    retailred.updateConfig({
                                        product: newData,
                                    });

                                    // shopware replaces the html after variant switch. so we need to add our buttons again
                                    render();
                                } catch (e) {
                                    console.error(e);
                                }
                            });
                            {/block}
                        });
                    } catch (e) {
                        console.error(e);
                    }
                </script>
            {/block}
        {/if}
    {/block}
{/block}


