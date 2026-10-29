class OrderInputError extends Error {
  constructor(message, code = 'INVALID_ORDER') {
    super(message);
    this.name = 'OrderInputError';
    this.statusCode = 400;
    this.code = code;
  }
}

const nameOf = (value) => String(value ?? '').trim();
const optionMatches = (option, id, name) =>
  String(option.id ?? option._id ?? option.code ?? option.name) === String(id) ||
  (name && String(option.name) === String(name));

function normalizeOrderItems(items, products, { branchId = '', brandId = '', modifierGroups = [] } = {}) {
  if (!Array.isArray(items) || items.length === 0) {
    throw new OrderInputError('Giỏ hàng đang trống.', 'EMPTY_ORDER');
  }

  const productMap = new Map();
  for (const product of products) {
    productMap.set(String(product._id), product);
    if (product.id) productMap.set(String(product.id), product);
  }
  const groupsById = new Map(modifierGroups.map((group) => [String(group.id ?? group._id), group]));
  let subtotal = 0;
  const normalizedItems = [];

  for (const input of items) {
    const product = productMap.get(String(input.productId));
    if (!product || product.isAvailable === false) {
      throw new OrderInputError(`Sản phẩm không khả dụng: ${input.productName || input.productId}`, 'PRODUCT_UNAVAILABLE');
    }
    if (brandId && product.brandId && product.brandId !== brandId) {
      throw new OrderInputError(`Sản phẩm ${product.name} không thuộc thương hiệu đã chọn.`, 'PRODUCT_BRAND_MISMATCH');
    }
    const availability = product.branchAvailability instanceof Map
      ? product.branchAvailability.get(branchId)
      : product.branchAvailability?.[branchId];
    if (branchId && availability === false) {
      throw new OrderInputError(`${product.name} hiện không bán tại cơ sở đã chọn.`, 'PRODUCT_UNAVAILABLE_AT_BRANCH');
    }

    const quantity = Number(input.quantity);
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 99) {
      throw new OrderInputError('Số lượng mỗi món phải từ 1 đến 99.', 'INVALID_QUANTITY');
    }

    const customization = input.customization && typeof input.customization === 'object'
      ? input.customization
      : {};
    const selected = Array.isArray(input.selectedModifiers)
      ? input.selectedModifiers
      : Array.isArray(customization.selectedModifiers) ? customization.selectedModifiers : [];
    const attachedGroupIds = Array.isArray(product.modifierGroupIds) ? product.modifierGroupIds.map(String) : [];
    const attachedGroups = attachedGroupIds.map((id) => groupsById.get(id)).filter((group) => group?.isActive !== false);
    let optionTotal = 0;
    const normalizedModifiers = [];

    if (attachedGroups.length) {
      for (const group of attachedGroups) {
        const chosen = selected.filter((item) => String(item.groupId ?? '') === String(group.id ?? group._id));
        const min = Number(group.minSelections ?? 0);
        const max = Number(group.maxSelections ?? 1);
        if (chosen.length < min || chosen.length > max || (group.selectionType === 'SINGLE' && chosen.length > 1)) {
          throw new OrderInputError(`Vui lòng chọn ${group.name} theo yêu cầu.`, 'INVALID_MODIFIER_SELECTION');
        }
        for (const choice of chosen) {
          const option = (group.options || []).find((item) => item.isAvailable !== false && optionMatches(item, choice.optionId, choice.optionName));
          if (!option) throw new OrderInputError(`Tùy chọn không hợp lệ trong nhóm ${group.name}.`, 'INVALID_PRODUCT_OPTION');
          const priceAdjustment = Number(option.priceAdjustment ?? option.extraPrice ?? 0);
          optionTotal += priceAdjustment;
          normalizedModifiers.push({
            groupId: String(group.id ?? group._id),
            groupName: group.name,
            optionId: String(option.id ?? option._id ?? option.name),
            optionName: option.name,
            priceAdjustment,
          });
        }
      }
    } else {
      const legacyGroups = [
        { key: 'sizes', id: 'sizeId', label: 'size' },
        { key: 'sugarLevels', id: 'sugarLevelId', label: 'sugar' },
        { key: 'iceLevels', id: 'iceLevelId', label: 'ice' },
        { key: 'toppings', id: 'toppingIds', label: 'topping' },
      ];
      const addLegacyOption = (group, option) => {
        const adjustment = Number(option.extraPrice ?? option.priceAdjustment ?? 0);
        optionTotal += adjustment;
        normalizedModifiers.push({
          groupId: `mod-${product.brandId || 'legacy'}-${group.label}`,
          groupName: group.label,
          optionId: String(option.id ?? option.code ?? option.name),
          optionName: option.name,
          priceAdjustment: adjustment,
        });
      };

      for (const group of legacyGroups) {
        const options = product[group.key] || [];
        if (!options.length) continue;
        const choices = selected.filter((item) => String(item.groupName || item.groupId || '').toLowerCase().includes(group.label));
        if (group.key === 'sizes' && !choices.length && !customization[group.id]) {
          const defaultSize = options.find((option) => option.isDefault);
          if (!defaultSize) throw new OrderInputError(`Vui lòng chọn kích cỡ cho ${product.name}.`, 'INVALID_PRODUCT_OPTION');
          addLegacyOption(group, defaultSize);
          continue;
        }
        if (group.key === 'toppings') {
          const ids = Array.isArray(customization.toppingIds) ? customization.toppingIds : [];
          const allChoices = choices.length ? choices : ids.map((optionId) => ({ optionId }));
          for (const choice of allChoices) {
            const option = options.find((item) => optionMatches(item, choice.optionId, choice.optionName));
            if (!option) throw new OrderInputError('Tùy chọn topping không hợp lệ.', 'INVALID_PRODUCT_OPTION');
            addLegacyOption(group, option);
          }
        } else {
          const choice = choices[0];
          const requestedId = choice?.optionId ?? customization[group.id];
          if (!requestedId) continue;
          const option = options.find((item) => optionMatches(item, requestedId, choice?.optionName));
          if (!option) throw new OrderInputError(`Tùy chọn ${group.label} không hợp lệ.`, 'INVALID_PRODUCT_OPTION');
          addLegacyOption(group, option);
        }
      }
    }

    const branchOverride = product.branchPriceOverrides instanceof Map
      ? product.branchPriceOverrides.get(branchId)
      : product.branchPriceOverrides?.[branchId];
    const unitPrice = Number(branchOverride ?? product.basePrice ?? product.price ?? 0) + optionTotal;
    const totalPrice = unitPrice * quantity;
    subtotal += totalPrice;
    normalizedItems.push({
      productId: String(product.id || product._id),
      productName: product.name,
      brandId: product.brandId || brandId || 'brand-legia',
      branchId,
      quantity,
      unitPrice,
      totalPrice,
      customization: { ...customization, selectedModifiers: normalizedModifiers },
      selectedModifiers: normalizedModifiers,
    });
  }

  return { normalizedItems, subtotal };
}

module.exports = { normalizeOrderItems, OrderInputError };
