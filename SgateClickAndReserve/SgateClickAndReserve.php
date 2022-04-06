<?php

namespace SgateClickAndReserve;

use Shopware\Bundle\CookieBundle\CookieCollection;
use Shopware\Bundle\CookieBundle\Structs\CookieGroupStruct;
use Shopware\Bundle\CookieBundle\Structs\CookieStruct;
use Shopware\Components\Plugin;
use Shopware\Components\Plugin\Context\ActivateContext;
use Shopware\Components\Plugin\Context\DeactivateContext;
use Shopware\Components\Plugin\Context\InstallContext;
use Shopware\Components\Plugin\Context\UninstallContext;

class SgateClickAndReserve extends Plugin
{
    /**
     * @param ActivateContext $context
     */
    public function activate(ActivateContext $context): void
    {
        $context->scheduleClearCache(array_merge(InstallContext::CACHE_LIST_FRONTEND, [InstallContext::CACHE_TAG_CONFIG]));
    }

    /**
     * @param DeactivateContext $context
     */
    public function deactivate(DeactivateContext $context): void
    {
        $context->scheduleClearCache(array_merge(InstallContext::CACHE_LIST_FRONTEND, [InstallContext::CACHE_TAG_CONFIG]));
    }

    /**
     * @param UninstallContext $context
     */
    public function uninstall(UninstallContext $context): void
    {
        // Clear only cache when switching from active state to uninstall
        if ($context->getPlugin()->getActive()) {
            $context->scheduleClearCache(array_merge(InstallContext::CACHE_LIST_FRONTEND, [InstallContext::CACHE_TAG_CONFIG]));
        }
    }

    public static function getSubscribedEvents(): array
    {
        return [
            'CookieCollector_Collect_Cookies' => 'addComfortCookie'
        ];
    }

    public function addComfortCookie(): CookieCollection
    {
        $pluginNamespace = $this->container->get('snippets')->getNamespace('i18n');

        $collection = new CookieCollection();
        $collection->add(new CookieStruct(
            'allow_local_storage',
            '/^match_no_cookie_djk5GA1P89dkUa2$/',
            $pluginNamespace->get('cookie'),
            CookieGroupStruct::COMFORT
        ));

        return $collection;
    }
}
